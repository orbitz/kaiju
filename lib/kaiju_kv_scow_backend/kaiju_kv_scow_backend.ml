open Core.Std
open Async.Std

module Stream_node = Scow_transport_stream_server.Node

module Obj = Kaiju_kv_backend.Obj

module Triplet = struct
  type t = (string * string * string option) with compare
end

module Elt = struct
  type t = Obj.t list

  module Build = Json_type.Build
  module Browse = Json_type.Browse

  let rec compare t1 t2 =
    match (t1, t2) with
      | ([], []) ->
        0
      | ([], _) ->
        -1
      | (_, []) ->
        1
      | (t1::t1s, t2::t2s) -> begin
        let triplet1 = (Obj.get_key t1, Obj.get_value t1, Obj.get_context t1) in
        let triplet2 = (Obj.get_key t2, Obj.get_value t2, Obj.get_context t2) in
        match Triplet.compare triplet1 triplet2 with
          | 0 -> compare t1s t2s
          | n -> n
      end

  let to_string objs =
    let objs_json =
      List.map
        ~f:(fun obj ->
          Build.objekt
            [ ("key",     Build.string (Obj.get_key obj))
            ; ("value",   Build.string (Obj.get_value obj))
            ; ("context", Build.option (Option.map ~f:Build.string (Obj.get_context obj)))
            ])
        objs
    in
    Json_io.string_of_json
      (Build.objekt
         [ ("values", Build.array objs_json) ])

  let of_json_exn table =
    let values = Browse.array (Browse.field table "values") in
    List.map
      ~f:(fun obj_json ->
        let table = Browse.make_table (Browse.objekt obj_json) in
        let key = Browse.string (Browse.field table "key") in
        let value = Browse.string (Browse.field table "value") in
        let context = Browse.optional Browse.string (Browse.field table "context") in
        Obj.create ~k:key ~v:value ~c:context)
      values

  let of_string_exn str =
    let objekt = Browse.objekt (Json_io.json_of_string str) in
    let table = Browse.make_table objekt in
    of_json_exn table

  let of_string str =
    printf "elt.of_string %s\n%!" str;
    Option.try_with (fun () -> of_string_exn str)
end

module Statem = struct
  type op  = Elt.t
  type ret = (unit, string list) Result.t
  type t   = Kaiju_kv_backend.t

  let create t = t

  let apply t op =
    Kaiju_kv_backend.put t op
end

module Json_codec = Scow_transport_stream_codec_json.Make(Elt)
module Log = Scow_log_memory.Make(Elt)
module Transport = Scow_transport_stream.Make(Json_codec)
module Store = Scow_store_memory.Make(Transport.Node)

module Scow = Scow.Make(Statem)(Log)(Store)(Transport)

type t = { scow   : Scow.t
         ; statem : Statem.t
         }

let origin = "kaiju_kv_scow_backend"

let do_put t objs =
  Scow.append_log t.scow objs
  >>| function
    | Ok (Ok ()) ->
      Ok ()
    | Ok (Error errors) ->
      Error (`Errors errors)
    | Error err ->
      Error err

let put t objs =
  do_put t objs
  >>= function
    | Ok () ->
      Deferred.return (Ok ())
    | Error (`Errors errors) ->
      Deferred.return (Error errors)
    | Error `Closed ->
      Deferred.return (Error ["scow closed"])
    | Error `Not_master -> begin
      Scow.leader t.scow
      >>= function
        | Ok leader_opt -> begin
          let leader_str =
            leader_opt
            |> Option.map ~f:Transport.Node.to_string
            |> Option.value ~default:"Unknown"
          in
          Deferred.return (Error [sprintf "leader is: %s" leader_str])
        end
        | Error _ ->
          Deferred.return (Error ["leader unknown"])
    end
    | Error `Append_failed
    | Error `Invalid_log ->
      Deferred.return (Error ["unknown error"])

let first t ?stop ~n start =
  printf "Received first %s\n%!" start;
  Kaiju_kv_backend.first t.statem ?stop ~n start

let next t =
  Kaiju_kv_backend.next t.statem

let delete t =
  Kaiju_kv_backend.delete t.statem

let get_config base_key config =
  let open Result.Monad_infix in
  Konfig.get (base_key @ ["me"]) config
  >>= fun me ->
  Konfig.get (base_key @ ["nodes"]) config
  >>= fun nodes ->
  Konfig.get (base_key @ ["backend"]) config
  >>= fun understore_key ->
  let understore_key = String.split ~on:'.' understore_key in
  Ok (me, nodes, understore_key)

let node_of_string node_str =
  match String.lsplit2 ~on:':' node_str with
    | Some (host, port) ->
      Option.value_exn (Stream_node.create ~host ~port:(Int.of_string port))
    | None ->
      failwith "nyi"

let nodes_of_string nodes_str =
  nodes_str
  |> String.split ~on:' '
  |> List.map ~f:node_of_string

let start_understore init_args understore_key =
  let module Ia  = Kaiju_kv_backend.Init_args in
  let module Cia = Kaiju_kv_backend.Callbacks.Init_args in
  let init_args = { Ia.log      = init_args.Cia.log
                  ;    config   = init_args.Cia.config
                  ;    base_key = init_args.Cia.base_key
                  ;    start    = Kaiju_kv_memory_backend.start
                  }
  in
  Kaiju_kv_backend.start init_args
  >>= function
    | Ok memory_backend -> Deferred.return (Ok memory_backend)
    | Error ()          -> Deferred.return (Error `Failed)


let do_start init_args =
  let module Kvb = Kaiju_kv_backend.Callbacks in
  let module Ia  = Kaiju_kv_backend.Callbacks.Init_args in
  let module Sia = Scow.Init_args in
  let base_key   = init_args.Ia.base_key in
  let config     = init_args.Ia.config in
  Deferred.return (get_config base_key config)
  >>=? fun (me_str, nodes_str, understore_key) ->
  let me = node_of_string me_str in
  let nodes = nodes_of_string nodes_str in
  Transport.start ~me
  >>=? fun transport ->
  start_understore init_args understore_key
  >>=? fun understore ->
  let log = Log.create () in
  let store = Store.create () in
  let statem = Statem.create understore in
  let init_args = { Sia.me = me
                  ;     nodes        = nodes
                  ;     statem       = statem
                  ;     transport    = transport
                  ;     log          = log
                  ;     store        = store
                  ;     timeout      = sec 1.0
                  ;     timeout_rand = sec 2.0
                  }
  in
  Scow.start init_args
  >>=? fun scow ->
  Deferred.return (Ok { scow; statem })

let start init_args =
  let module Ia  = Kaiju_kv_backend.Callbacks.Init_args in
  let module Kvb = Kaiju_kv_backend.Callbacks in
  do_start init_args
  >>= function
    | Ok t -> begin
      Zolog_event.info
        ~n:["kaiju"; "kv"; "backend"; "scow"; "start"]
        ~o:origin
        init_args.Ia.log
        "Started key-value scow backend"
      >>= fun _ ->
      Deferred.return (Ok { Kvb.put    = put t
                          ;     first  = first t
                          ;     next   = next t
                          ;     delete = delete t
                          })
    end
    | Error _ ->
      Deferred.return (Error ())

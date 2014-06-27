open Core.Std
open Async.Std

module Obj = Kaiju_kv_backend.Obj

let origin = "kaiju_kv_line_transport"

module Server = struct
  type t = { log     : Zolog_std_event.t Zolog.t
           ; backend : Kaiju_kv_backend.t
           ; reader  : Reader.t
           ; writer  : Writer.t
           }

  let write_objs writer objs =
    List.iter
      ~f:(fun obj ->
        Writer.write
          writer
          (String.concat
             ~sep:" "
             [ Obj.get_key obj
             ; Obj.get_value obj
             ; Option.value (Obj.get_context obj) ~default:"unknown"
             ]);
        Writer.write writer "\n")
      objs

  let put state key value context =
    let obj = Obj.create ~k:key ~v:value ~c:context in
    Kaiju_kv_backend.put
      state.backend
      [obj]
    >>= function
      | Ok () ->
        Deferred.return (Ok ())
      | Error errors -> begin
        List.iter
          ~f:(fun key ->
            Writer.write
              state.writer
              (key ^ "\n"))
          errors;
        Deferred.return (Ok ())
      end

  let handle_line state line =
    match String.split ~on:' ' line with
      | ["GET"; key] -> begin
        Kaiju_kv_backend.get
          state.backend
          [key]
        >>=? fun objs ->
        write_objs state.writer objs;
        Deferred.return (Ok ())
      end
      | ["PUT"; key; value] -> begin
        put state key value None
      end
      | ["PUT"; key; context; value] ->
        put state key value (Some context)
      | _ ->
        Deferred.return (Error ())

  let rec loop state =
    Reader.read_line state.reader
    >>= function
      | `Ok line -> begin
        handle_line state line
        >>= function
          | Ok () ->
            loop state
          | Error () ->
            Deferred.unit
      end
      | `Eof ->
        Deferred.unit

  let start init_args _ reader writer =
    let module Ia = Kaiju_kv_transport.Callbacks.Init_args in
    loop { log     = init_args.Ia.log
         ; backend = init_args.Ia.backend
         ; reader
         ; writer
         }
end

let log_error log err =
  let string_of_err = function
    | `Missing_port ->
        "Missing port for line transport"
    | `Invalid_port s ->
      sprintf
        "Port must be an integer: %s"
        s
  in
  Zolog_event.error
    ~n:["kaiju"; "kv"; "transport"; "line"; "start"]
    ~o:origin
    log
    (string_of_err err)
  >>= fun _ ->
  Zolog.sync log

let port_of_string s =
  match Option.try_with (fun () -> Int.of_string s) with
    | Some port -> Ok port
    | None      -> Error (`Invalid_port s)

let get_port init_args =
  let module Ia = Kaiju_kv_transport.Callbacks.Init_args in
  match Konfig.get (init_args.Ia.base_key @ ["port"]) init_args.Ia.config with
    | Ok port_s -> Deferred.return (port_of_string port_s)
    | Error _   -> Deferred.return (Error `Missing_port)

let do_start init_args =
  get_port init_args >>=? fun port ->
  ignore (Tcp.Server.create
            (Tcp.on_port port)
            (Server.start init_args));
  Deferred.return (Ok ())

let start init_args =
  let module Ia = Kaiju_kv_transport.Callbacks.Init_args in
  do_start init_args
  >>= function
    | Ok () ->
      Zolog_event.info
        ~n:["kaiju"; "kv"; "transport"; "line"; "start"]
        ~o:origin
        init_args.Ia.log
        "Started key-value line transport"
      >>= fun _ ->
      Deferred.return (Ok ())
    | Error err ->
      log_error init_args.Ia.log err >>= fun _ ->
      Deferred.return (Error ())


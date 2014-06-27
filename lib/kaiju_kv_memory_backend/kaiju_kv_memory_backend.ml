open Core.Std
open Async.Std

module Obj = Kaiju_kv_backend.Obj

type t = { mutable db : (string * int) String.Map.t }

let put t objs =
  let (errors, db) =
    List.fold_left
      ~f:(fun (errors, db) obj ->
        let ctx = Int.of_string (Option.value (Obj.get_context obj) ~default:"0") in
        match Map.find t.db (Obj.get_key obj) with
          | Some (value, context) when ctx = context ->
            (errors,
             Map.add
               ~key:(Obj.get_key obj)
               ~data:(Obj.get_value obj, ctx + 1)
               db)
          | Some _ ->
            ((Obj.get_key obj)::errors, db)
          | None ->
            (errors,
             Map.add
               ~key:(Obj.get_key obj)
               ~data:(Obj.get_value obj, ctx + 1)
               db))
      ~init:([], t.db)
      objs
  in
  t.db <- db;
  match errors with
    | [] ->
      Deferred.return (Ok ())
    | errors ->
      Deferred.return (Error errors)

let get t keys =
  let objs =
    List.fold_left
      ~f:(fun objs key ->
        match Map.find t.db key with
          | Some (value, context) ->
            (Obj.create ~k:key ~v:value ~c:(Some (Int.to_string context)))::objs
          | None ->
            objs)
      ~init:[]
      keys
  in
  Deferred.return (Ok objs)

let get_range t ~n (kstart, kend) = failwith "nyi"
let delete t objs = failwith "nyi"

let start init_args =
  let module Kvb = Kaiju_kv_backend.Callbacks in
  let t = { db = String.Map.empty } in
  Deferred.return (Ok { Kvb.put       = put t
                      ;     get       = get t
                      ;     get_range = get_range t
                      ;     delete    = delete t
                      })

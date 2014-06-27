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

let is_leq_than_stop key = function
  | Some stop -> String.compare key stop <= 0
  | None      -> true

let rec do_next acc t ~stop ~n start =
  if n > 0 then begin
    match Map.next_key t.db start with
      | Some (key, (value, context)) when is_leq_than_stop key stop ->
        let acc' =
          (Obj.create ~k:key ~v:value ~c:(Some (Int.to_string context)))::acc
        in
        do_next acc' t ~stop ~n:(n - 1) key
      | Some _ | None ->
        List.rev acc
  end
  else
    List.rev acc

let first t ?stop ~n start =
  match Map.find t.db start with
    | Some (value, context) ->
      let acc =
        [Obj.create ~k:start ~v:value ~c:(Some (Int.to_string context))]
      in
      Deferred.return (Ok (do_next acc t ~stop ~n:(n - 1) start))
    | None ->
      Deferred.return (Ok (do_next [] t ~stop ~n start))


let next t ?stop ~n start =
  Deferred.return (Ok (do_next [] t ~stop ~n start))

let delete t objs = failwith "nyi"

let start init_args =
  let module Kvb = Kaiju_kv_backend.Callbacks in
  let t = { db = String.Map.empty } in
  Deferred.return (Ok { Kvb.put    = put t
                      ;     first  = first t
                      ;     next   = next t
                      ;     delete = delete t
                      })

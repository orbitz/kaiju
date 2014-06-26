open Core.Std
open Async.Std

type t = unit

let put t objs = failwith "nyi"
let get t keys = failwith "nyi"
let get_range t ~n (kstart, kend) = failwith "nyi"
let delete t objs = failwith "nyi"

let start init_args =
  let module Kvb = Kaiju_kv_backend.Callbacks in
  let t = () in
  Deferred.return (Ok { Kvb.put       = put t
                      ;     get       = get t
                      ;     get_range = get_range t
                      ;     delete    = delete t
                      })

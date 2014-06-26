open Async.Std

type t = unit

module Obj = struct
  type t = { key     : string
           ; value   : string
           ; context : string
           }

  let create ~k ~v ~c = { key = k; value = v; context = c }

  let get_key t     = t.key
  let get_value t   = t.value
  let get_context t = t.context
end

module Callbacks = struct
  module Init_args = struct
    type t = { log      : Zolog_std_event.t Zolog.t
             ; config   : Konfig.t
             ; base_key : string list
             }
  end

  type c = { start     : Init_args.t -> (t, unit) Deferred.Result.t
           ; put       : t -> Obj.t list -> (unit, string list) Deferred.Result.t
           ; get       : t -> string list -> (Obj.t list, unit) Deferred.Result.t
           ; get_range : t -> n:int -> (string * string) -> (Obj.t list, unit) Deferred.Result.t
           ; delete    : t -> Obj.t list -> (unit, unit) Deferred.Result.t
           }

  type t = c
end

module Init_args = struct
  type t = { log       : Zolog_std_event.t Zolog.t
           ; config    : Konfig.t
           ; base_key  : string list
           ; callbacks : Callbacks.t
           }
end

let start init_args = failwith "nyi"
let put t objs = failwith "nyi"
let get t keys = failwith "nyi"
let get_range t ~n (kstart, kend) = failwith "nyi"
let delete t objs = failwith "nyi"

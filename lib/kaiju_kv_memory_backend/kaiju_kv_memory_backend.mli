open Async.Std

val start     : Kaiju_kv_backend.Callbacks.Init_args.t -> (Kaiju_kv_backend.t, unit) Deferred.Result.t
val put       : Kaiju_kv_backend.t -> Kaiju_kv_backend.Obj.t list -> (unit, string list) Deferred.Result.t
val get       : Kaiju_kv_backend.t -> string list -> (Kaiju_kv_backend.Obj.t list, unit) Deferred.Result.t
val get_range : Kaiju_kv_backend.t -> n:int -> (string * string) -> (Kaiju_kv_backend.Obj.t list, unit) Deferred.Result.t
val delete    : Kaiju_kv_backend.t -> Kaiju_kv_backend.Obj.t list -> (unit, unit) Deferred.Result.t

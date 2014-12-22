open Async.Std

val start :
  Kaiju_kv_backend.Callbacks.Init_args.t ->
  (Kaiju_kv_backend.Callbacks.t, unit) Deferred.Result.t

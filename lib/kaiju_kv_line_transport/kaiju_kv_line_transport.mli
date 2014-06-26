open Async.Std

val start : Kaiju_kv_transport.Callbacks.Init_args.t -> (unit, unit) Deferred.Result.t

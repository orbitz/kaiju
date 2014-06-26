open Async.Std

type init_args = { log        : Zolog_std_event.t Zolog.t
                 ; base       : string list
                 ; config     : Konfig.t
                 ; backends   : (string * Kaiju_kv_backend.Callbacks.t) list
                 ; transports : (string * Kaiju_kv_transport.Callbacks.t) list
                 }

val start : init_args -> unit Deferred.t

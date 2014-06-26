open Async.Std

type t

module Callbacks : sig
  module Init_args : sig
    type t = { log      : Zolog_std_event.t Zolog.t
             ; config   : Konfig.t
             ; base_key : string list
             ; backend  : Kaiju_kv_backend.t
             }
  end

  type c = { start : Init_args.t -> (t, unit) Deferred.Result.t }
  type t = c
end

module Init_args : sig
  type t = { log       : Zolog_std_event.t Zolog.t
           ; config    : Konfig.t
           ; base_key  : string list
           ; backend   : Kaiju_kv_backend.t
           ; callbacks : Callbacks.t
           }
end

val start : Init_args.t -> (t, unit) Deferred.Result.t

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

  type start = Init_args.t -> (unit, unit) Deferred.Result.t

end

module Init_args : sig
  type t = { log      : Zolog_std_event.t Zolog.t
           ; config   : Konfig.t
           ; base_key : string list
           ; backend  : Kaiju_kv_backend.t
           ; start    : Callbacks.start
           }
end

val start : Init_args.t -> (unit, unit) Deferred.Result.t

open Core.Std
open Async.Std

type t = unit

module Callbacks = struct
  module Init_args = struct
    type t = { log      : Zolog_std_event.t Zolog.t
             ; config   : Konfig.t
             ; base_key : string list
             ; backend  : Kaiju_kv_backend.t
             }
  end

  type c = { start : Init_args.t -> (t, unit) Deferred.Result.t }
  type t = c
end

module Init_args = struct
  type t = { log       : Zolog_std_event.t Zolog.t
           ; config    : Konfig.t
           ; base_key  : string list
           ; backend   : Kaiju_kv_backend.t
           ; callbacks : Callbacks.t
           }
end

let start init_args = failwith "nyi"


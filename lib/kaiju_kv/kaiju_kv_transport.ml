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

  type start = Init_args.t -> (t, unit) Deferred.Result.t
end

module Init_args = struct
  type t = { log      : Zolog_std_event.t Zolog.t
           ; config   : Konfig.t
           ; base_key : string list
           ; backend  : Kaiju_kv_backend.t
           ; start    : Callbacks.start
           }
end

let start init_args =
  let module Cia = Callbacks.Init_args in
  init_args.Init_args.start
    { Cia.log      = init_args.Init_args.log
    ;     config   = init_args.Init_args.config
    ;     base_key = init_args.Init_args.base_key
    ;     backend  = init_args.Init_args.backend
    }
  >>=? fun () ->
  Deferred.return (Ok ())

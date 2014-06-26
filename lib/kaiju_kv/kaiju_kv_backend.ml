open Core.Std
open Async.Std

module Obj = struct
  type t = { key     : string
           ; value   : string
           ; context : string option
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

  type t = { put       : Obj.t list -> (unit, string list) Deferred.Result.t
           ; get       : string list -> (Obj.t list, unit) Deferred.Result.t
           ; get_range : n:int -> (string * string) -> (Obj.t list, unit) Deferred.Result.t
           ; delete    : Obj.t list -> (unit, unit) Deferred.Result.t
           }

  type start = Init_args.t -> (t, unit) Deferred.Result.t
end

module Init_args = struct
  type t = { log      : Zolog_std_event.t Zolog.t
           ; config   : Konfig.t
           ; base_key : string list
           ; start    : Callbacks.start
           }
end

type t = { callbacks : Callbacks.t }

let start init_args =
  let module Cia = Callbacks.Init_args in
  init_args.Init_args.start
    { Cia.log      = init_args.Init_args.log
    ;     config   = init_args.Init_args.config
    ;     base_key = init_args.Init_args.base_key
    }
  >>=? fun callbacks ->
  Deferred.return (Ok { callbacks })

let put t objs =
  let module Cb = Callbacks in
  t.callbacks.Cb.put objs

let get t keys =
  let module Cb = Callbacks in
  t.callbacks.Cb.get keys

let get_range t ~n range =
  let module Cb = Callbacks in
  t.callbacks.Cb.get_range ~n range

let delete t objs =
  let module Cb = Callbacks in
  t.callbacks.Cb.delete objs

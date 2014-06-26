open Async.Std

type t

module Obj : sig
  type t

  val create      : k:string -> v:string -> c:string -> t
  val get_key     : t -> string
  val get_value   : t -> string
  val get_context : t -> string
end

module Callbacks : sig
  module Init_args : sig
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

module Init_args : sig
  type t = { log      : Zolog_std_event.t Zolog.t
           ; config   : Konfig.t
           ; base_key : string list
           ; start    : Callbacks.start
           }
end

val start     : Init_args.t -> (t, unit) Deferred.Result.t
val put       : t -> Obj.t list -> (unit, string list) Deferred.Result.t
val get       : t -> string list -> (Obj.t list, unit) Deferred.Result.t
val get_range : t -> n:int -> (string * string) -> (Obj.t list, unit) Deferred.Result.t
val delete    : t -> Obj.t list -> (unit, unit) Deferred.Result.t

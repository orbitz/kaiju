open Async.Std

module Init_args : sig
  type t = { name     : string
           ; base_key : string list
           ; config   : Konfig.t
           ; log      : Zolog_std_event.t Zolog.t
           }
end

(*
 * KAIJU_KV defines the interface of a Kaiju key-value implemenation.
 * The semantics are purposefully loose, giving an implementation
 * the freedom to provide any set of semantics that fit inside the
 * interface.  Users of a backend should be careful to understand the
 * semantics of a chosen backend.
 *
 * Backends are expected to handle concurrent calls safely.
 *
 * There is no "stop" function because all backends are expected to
 * operate in a "crash-only" environment.
 *)
module type KAIJU_KV = sig
  type t
  type obj

  (*
   * Start an instances of the kv-store.  The input includes:
   * - The name that the system wants to give to the store, this
   *   should be used in logging.
   * - The config, this contains the whole systems config values.
   * - The base key that the config values for this store will
   *   be allocated under.
   *
   * After [start] returns, any of the other operations can be
   * performed on the store.
   *)
  val start : Init_args.t -> (t, unit) Deferred.Result.t

  (*
   * Put a set of values.  This is not required to be atomic,
   * individual puts may fail.  The order in which the actual
   * puts are executed is undefined.
   *)
  val put : t -> obj list -> (unit, string list) Deferred.Result.t

  (*
   * Get a list of keys.  The order in which keys are returned is
   * undefined.  However the above machinery will not modify the
   * order that the backend gives them in.
  *)
  val get : t -> string list -> (obj option list, unit) Deferred.Result.t

  (*
   * Get a range of keys \[start, end\] or at most [n] keys starting at [start].
  *)
  val get_range : t -> n:int -> (string * string) -> (obj list, unit) Deferred.Result.t

  (*
   * Delete a list of objects.  The order in which the deletes are
   * executed is undefined.  A delete may fail.
  *)
  val delete : t -> obj list -> (unit, string list) Deferred.Result.t
end

module type TRANSPORT = sig
  type t

  val create : Init_args.t -> (t, unit) Deferred.Result.t
end

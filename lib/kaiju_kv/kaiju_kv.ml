open Core.Std
open Async.Std

type init_args = { log        : Zolog_std_event.t Zolog.t
                 ; base       : string list
                 ; config     : Konfig.t
                 ; backends   : (string * Kaiju_kv_backend.Callbacks.t) list
                 ; transports : (string * Kaiju_kv_transport.Callbacks.t) list
                 }

let origin = "kaiju_kv"

let log_message_and_exit log err =
  let string_of_err = function
    | `Not_found k ->
      sprintf
        "Storage config key not found: %s"
        (String.concat ~sep:"." k)
    | `Unknown_backend backend_type ->
      sprintf
        "Unknown backend type: %s"
        backend_type
    | `Unknown_transport transport_type ->
      sprintf
        "Unknown transport type: %s"
        transport_type
    | `Failed_to_start ->
      "Failed to start backend or transport"
  in
  Zolog_event.error
    ~n:["kaiju"; "kv"; "start"]
    ~o:origin
    log
    (string_of_err err)
  >>= fun _ ->
  Zolog.sync log
  >>= fun _ ->
  Deferred.return (shutdown 1)

let lookup_backend init_args =
  let open Result.Monad_infix in
  Konfig.get
       (init_args.base @ ["backend"; "type"])
       init_args.config
  >>= fun backend_type ->
  match List.Assoc.find init_args.backends backend_type with
    | Some backend_cb -> Ok backend_cb
    | None            -> Error (`Unknown_backend backend_type)

let lookup_transport init_args =
  let open Result.Monad_infix in
  Konfig.get
    (init_args.base @ ["transport"; "type"])
    init_args.config
  >>= fun transport_type ->
  match List.Assoc.find init_args.transports transport_type with
    | Some transport_cb -> Ok transport_cb
    | None              -> Error (`Unknown_transport transport_type)

let start_kv init_args backend_cb transport_cb =
  let module Kvb = Kaiju_kv_backend in
  let module Kvt = Kaiju_kv_transport in
  let backend_init_args = { Kvb.Init_args.log       = init_args.log
                          ;               config    = init_args.config
                          ;               base_key  = init_args.base @ ["backend"]
                          ;               callbacks = backend_cb
                          }
  in
  Kaiju_kv_backend.start backend_init_args
  >>=? fun backend ->
  let transport_init_args = { Kvt.Init_args.log       = init_args.log
                            ;               config    = init_args.config
                            ;               base_key  = init_args.base @ ["transport"]
                            ;               backend   = backend
                            ;               callbacks = transport_cb
                            }
  in
  Kaiju_kv_transport.start transport_init_args
  >>=? fun _ ->
  Deferred.return (Ok ())


let do_start init_args =
  let backend_transport =
    let open Result.Monad_infix in
    lookup_backend init_args   >>= fun backend_cb ->
    lookup_transport init_args >>= fun transport_cb ->
    Ok (backend_cb, transport_cb)
  in
  Deferred.return backend_transport
  >>=? fun (backend_cb, transport_cb) ->
  start_kv init_args backend_cb transport_cb
  >>= function
    | Ok ()    -> Deferred.return (Ok ())
    | Error () -> Deferred.return (Error `Failed_to_start)

let start init_args =
  do_start init_args
  >>= function
    | Ok () -> begin
      Zolog_event.info
        ~n:["kaiju"; "kv"; "start"]
        ~o:origin
        init_args.log
        "Started key-value store"
      >>= fun _ ->
      Deferred.unit
    end
    | Error err ->
      log_message_and_exit init_args.log err

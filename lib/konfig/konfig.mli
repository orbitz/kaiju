open Core.Std

type t

val parse_string : string -> (t, [> `Parse_error of string ]) Result.t

val get          : string list -> t -> (string, [> `Not_found of string list ]) Result.t

val to_list      : t -> (string list * string) list

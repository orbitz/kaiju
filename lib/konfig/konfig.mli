open Core.Std

type t

val parse_string : string -> (t, string) Result.t

val get          : string list -> t -> string option

val to_list      : t -> (string list * string) list

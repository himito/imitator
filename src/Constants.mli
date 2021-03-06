(************************************************************
 *
 *                       IMITATOR
 * 
 * Laboratoire Spécification et Vérification (ENS Cachan & CNRS, France)
 * LIPN, Université Paris 13, Sorbonne Paris Cité (France)
 * 
 * All (?) constants of IMITATOR
 * 
 * File contributors : Étienne André
 * Created           : 2014/10/24
 * Last modified     : 2017/06/27
 *
 ************************************************************)

 
(************************************************************)
(************************************************************)
(* IMITATOR NAME AND VERSION *)
(************************************************************)
(************************************************************)

val program_name : string

val version_string : string

val version_name : string

(* Path ending with "/" *)
val path_to_program : string


(************************************************************)
(************************************************************)
(* External binaries *)
(************************************************************)
(************************************************************)

val dot_command : string


(************************************************************)
(************************************************************)
(* FILE EXTENSIONS *)
(************************************************************)
(************************************************************)


(** Extension for input model files *)
val model_extension : string

(** Extension for files output *)
val result_file_extension : string

val default_dot_image_extension : string
val dot_file_extension : string
val states_file_extension : string
val cartography_extension : string

(************************************************************)
(************************************************************)
(* Hashtable initial size (just a guess) *)
(************************************************************)
(************************************************************)
val guessed_nb_states_for_hashtable : int


(************************************************************)
(************************************************************)
(* Internal cuisine *)
(************************************************************)
(************************************************************)
(* Name of the special clock always reset (used for NZ model checking, and not to be printed in normal operations) *)
val special_reset_clock_name : string

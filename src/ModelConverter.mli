(************************************************************
 *
 *                       IMITATOR
 * 
 * Laboratoire Spécification et Vérification (ENS Cachan & CNRS, France)
 * LIPN, Université Paris 13, Sorbonne Paris Cité (France)
 * 
 * Module description: Convert a parsing structure into an abstract model
 * 
 * File contributors : Étienne André
 * Created           : 2009/09/09
 * Last modified     : 2016/10/08
 *
 ************************************************************)
 
 
(****************************************************************)
(** Modules *)
(****************************************************************)


(****************************************************************)
(** Exceptions *)
(****************************************************************)

(* When checking pi0 *)
exception InvalidPi0
(* When checking v0 *)
exception InvalidV0



(****************************************************************)
(** Conversion functions *)
(****************************************************************)
(** Check and convert the parsing structure into an abstract model *)
val abstract_model_of_parsing_structure : Options.imitator_options -> bool -> ParsingStructure.parsing_structure -> AbstractModel.abstract_model

(** Check and convert the parsed reference parameter valuation into an abstract representation *)
val check_and_make_pi0 : ParsingStructure.pi0 -> (*Options.imitator_options ->*) PVal.pval

(** Check and convert the parsed hyper-rectangle into an abstract representation *)
val check_and_make_v0 : ParsingStructure.v0 -> (*Options.imitator_options ->*) HyperRectangle.hyper_rectangle

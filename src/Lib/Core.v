Require Export Coq.Strings.String.
Require Export Coq.Lists.List.
Require Export Coq.ZArith.ZArith.
Require Export Coq.micromega.Lia.
Require Export bedrock2.Array.
Require Export bedrock2.BasicC64Semantics.
Require Export bedrock2.Map.Separation.
Require Export bedrock2.ProgramLogic.
Require Export bedrock2.Map.SeparationLogic.
Require Export bedrock2.Scalars.
Require Export bedrock2.Syntax.
Require Export bedrock2.WeakestPreconditionProperties.
Require Export coqutil.dlet.
Require Export coqutil.Map.Interface coqutil.Map.Properties coqutil.Map.SortedList.
Require Export coqutil.Tactics.Tactics.
Require Export coqutil.Tactics.letexists.
Require Export coqutil.Word.Interface coqutil.Word.Properties.
Require bedrock2.ProgramLogic.

Open Scope string_scope.
Export ListNotations.

Declare Scope sep_scope.
Delimit Scope sep_scope with sep.
Infix "*" := (sep) : sep_scope.

Set Nested Proofs Allowed.

(* TODO: once bedrock2 version is updated, these can be replaced by the
   commented-out generalized version below. *)

Local Existing Instance BasicC64Semantics.parameters.
Local Existing Instance BasicC64Semantics.parameters_ok.
(*
Context {p : Semantics.parameters} {word_size_in_bytes : Z}.
Context {p_ok : Semantics.parameters_ok p}.
 *)

Notation word := Semantics.word.

(* FIXME instead of cbn [fst snd], use simpl never hints in the sep case *)
Arguments Semantics.word : simpl never.

Notation address := word (only parsing).

Definition bedrock_func : Type :=
  string * (list string * list string * cmd).
Coercion name_of_func (f : bedrock_func) := fst f.

(* FIXME update bedrock2 to get rid of Byte.byte *)

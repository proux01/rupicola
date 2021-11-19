Require Import Coq.Strings.String Coq.Strings.Ascii.

Section Spec.
  Open Scope string_scope.

  Fixpoint string_map (f: ascii -> ascii) (s: String.string) :=
    match s with
    | EmptyString => EmptyString
    | String a s => String (f a) (string_map f s)
    end.

  Definition upchar_spec (c: ascii) :=
    match c with
    | "a" => "A" | "b" => "B" | "c" => "C" | "d" => "D"
    | "e" => "E" | "f" => "F" | "g" => "G" | "h" => "H"
    | "i" => "I" | "j" => "J" | "k" => "K" | "l" => "L"
    | "m" => "M" | "n" => "N" | "o" => "O" | "p" => "P"
    | "q" => "Q" | "r" => "R" | "s" => "S" | "t" => "T"
    | "u" => "U" | "v" => "V" | "w" => "W" | "x" => "X"
    | "y" => "Y" | "z" => "Z" | c => c
    end%char.

  Definition upstr_spec (s: string) :=
    string_map upchar_spec s.

  Compute upstr_spec "rupicola".
End Spec.

Require Import Coq.Strings.Byte.
Require Import Rupicola.Lib.Api.
Require Import Rupicola.Lib.Loops.
Require Import Rupicola.Lib.Arrays.
Require Import bedrock2.BasicC32Semantics.

Section Impl.
  Definition upchar_impl (b: byte) :=
    if byte.wrap (byte.unsigned b - byte.unsigned "a"%byte) <? 26
    then byte.and b x5f else b.

  Lemma upchar_impl_ok a:
    upchar_spec a = ascii_of_byte (upchar_impl (byte_of_ascii a)).
  Proof. destruct a as [[|][|][|][|][|][|][|][|]]; reflexivity. Qed.

  Lemma upchar_impl_ok' b:
    byte_of_ascii (upchar_spec (ascii_of_byte b)) = upchar_impl b.
  Proof. destruct b; reflexivity. Qed.

  Definition upstr_impl (s: list byte) :=
    let/n s := nd_ranged_for_all
                0 (Z.of_nat (length s))
                (fun s idx =>
                   let/n b := ListArray.get s idx in
                   let/n b := upchar_impl b in
                   let/n s := ListArray.put s idx b in
                   s) s in
    s.

  Lemma string_map_is_map f s:
    string_map f s = string_of_list_ascii (List.map f (list_ascii_of_string s)).
  Proof. induction s; simpl; congruence. Qed.

  Lemma upstr_impl_ok bs:
    upstr_impl bs = list_byte_of_string (upstr_spec (string_of_list_byte bs)).
  Proof.
    unfold upstr_spec, upstr_impl, nlet,
      list_byte_of_string, string_of_list_byte,
      ListArray.get, ListArray.put, cast, Convertible_Z_nat.
    rewrite string_map_is_map, !list_ascii_of_string_of_list_ascii, !map_map.
      symmetry; apply map_as_nd_ranged_for_all.
    intros; erewrite !Nat2Z.id, nth_indep, upchar_impl_ok' by lia.
      reflexivity.
  Qed.

  Lemma upstr_impl_ok' s:
    upstr_spec s = string_of_list_byte (upstr_impl (list_byte_of_string s)).
  Proof. rewrite upstr_impl_ok, !string_of_list_byte_of_string; reflexivity. Qed.
End Impl.

Section Upstr.
  Instance spec_of_upstr : spec_of "upstr" :=
    fnspec! "upstr" s_ptr wlen / (s : list byte) R,
      { requires tr mem :=
          wlen = word.of_Z (Z.of_nat (length s)) /\
          Z.of_nat (Datatypes.length s) < 2 ^ 32 /\ (* FIXME implied by sep *)
          (sizedlistarray_value AccessByte (length s) s_ptr s * R)%sep mem;
        ensures tr' mem' :=
          tr' = tr /\
          (sizedlistarray_value AccessByte (length s) s_ptr (upstr_impl s) * R)%sep mem' }.

  Import LoopCompiler.
  Import SizedListArrayCompiler.

  Hint Rewrite Nat2Z.id : compiler_cleanup.
  Hint Rewrite Z2Nat.id using eauto with lia : compiler_side_conditions.

  #[local] Hint Unfold upchar_impl : compiler_cleanup.
  #[local] Hint Extern 1 => cbn; nia : compiler_side_conditions.

  Derive upstr_body SuchThat
         (defn! "upstr" ("s", "len")
           { upstr_body },
           implements upstr_impl)
         As upstr_body_correct.
  Proof.
    Time compile.
  Time Qed.
End Upstr.

Definition upstr_br2func : func := ("upstr", (["s"; "len"], [], upstr_body)).
Definition upstr_cbytes := Eval vm_compute in
  list_byte_of_string (ToCString.c_module [upstr_br2func]).

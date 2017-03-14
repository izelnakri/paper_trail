- add setter_id foreign-key column, PaperTrail.insert_all, insert! and friends
- if I ever do the merging logic keep it in mind that updated_at of the record
must be sourced from the inserted_at of the version/
** add PaperTrail.insert!, PaperTrail.update!, PaperTrail.delete! # it shouldnt return a version, it shouldnt give errors/raise?(optional?)

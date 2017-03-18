- insert! and friends,
- PaperTrail.insert_all, update_all, delete_all
- insert_or_update, insert_or_update!
- if I ever do the merging logic keep it in mind that updated_at of the record
must be sourced from the inserted_at of the version/
** add PaperTrail.insert!, PaperTrail.update!, PaperTrail.delete! # it shouldnt return a version, it shouldnt give errors/raise?(optional?)

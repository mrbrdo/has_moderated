# Changelog

## v1.1.3

* more consistent behavior of without_moderation

## v1.1.2

* added Moderation class method without_moderation to disable moderations globally for all models

## v1.1.1

* accept and accept! now accept hash parameters that will be passed on to model#save

## v1.1

* accept now returns false if validations don't pass, otherwise returns true
* accept! added (raises exception if validations don't pass)

## v1.0.1

* Fix issue #12

## v1.0.rc11

* Moderation#destroy now calls Moderation#discard automatically.

## v1.0.rc10

* Use get\_moderation\_attributes when using has\_moderated to moderate attributes on update (previously only used in create moderations).

## v1.0.rc9

* Updated preview and live\_preview
* Updated README

## v1.0.rc6

* Make tests pass on 1.8.x and rubinius.

## v1.0.rc5

* Support moderation.preview for associations

## v1.0.rc4

* Refactoring
* Bug fixes
* moderation.preview feature
* changed moderations database table schema

## v0.0.34

* Now moderates deleting associations when using has\_moderated\_association

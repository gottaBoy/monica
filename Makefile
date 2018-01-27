GIT_TAG := $(shell git describe --abbrev=0 --tags)
VERSION := $(GIT_TAG)$(shell if ! $$(git describe --abbrev=0 --tags --exact-match 2>1 >/dev/null); then echo "-dev"; fi)
ifneq ($(TRAVIS_BUILD_NUMBER),)
VERSION := $(VERSION)-build$(TRAVIS_BUILD_NUMBER)
endif
DESTDIR := monica-$(VERSION)

docker: docker_build docker_tag docker_push

docker_build:
	docker-compose build

docker_tag:
	docker tag monicahq/monicahq monicahq/monicahq:$(GIT_TAG)

docker_push:
	docker push monicahq/monicahq:$(GIT_TAG)
	docker push monicahq/monicahq:latest

.PHONY: docker_build docker_tag docker_push


build:
	composer install --no-interaction --prefer-dist --no-suggest
	npm install
	npm run production

prepare: $(DESTDIR)
	mkdir -p results

$(DESTDIR):
	mkdir -p $@
	ln -s ../readme.md $@/
	ln -s ../CODE_OF_CONDUCT.md $@/
	ln -s ../CONTRIBUTING.md $@/
	ln -s ../app $@/
	ln -s ../app.json $@/
	ln -s ../artisan $@/
	ln -s ../bootstrap $@/
	ln -s ../CHANGELOG $@/
	ln -s ../composer.json $@/
	ln -s ../composer.lock $@/
	ln -s ../config $@/
	ln -s ../CONTRIBUTORS $@/
	ln -s ../database $@/
	ln -s ../docs $@/
	ln -s ../.env.example $@/
	ln -s ../LICENSE $@/
	ln -s ../nginx_app.conf $@/
	ln -s ../package.json $@/
	ln -s ../package-lock.json $@/
	ln -s ../phpunit.xml $@/
	ln -s ../Procfile $@/
	ln -s ../public $@/
	ln -s ../resources $@/
	ln -s ../routes $@/
	ln -s ../server.php $@/
	ln -s ../storage $@/
	ln -s ../tests $@/
	ln -s ../webpack.mix.js $@/

dist: results/$(DESTDIR).tar.gz results/$(DESTDIR).zip
	sed -s "s/\$$(version)/$(VERSION)/" .travis.deploy.json.in > .travis.deploy.json

results/$(DESTDIR).tar.gz: prepare
	tar chfvz $@ --exclude .gitignore --exclude .gitkeep $(DESTDIR)

results/$(DESTDIR).zip: prepare
	zip -rv9 $@ $(DESTDIR) --exclude "*.gitignore*" "*.gitkeep*"

clean:
	rm -rf $(DESTDIR)
	rm -f results/$(DESTDIR).tar.gz
	rm -f results/$(DESTDIR).zip
	rm -f .travis.deploy.json

fullclean: clean
	rm -rf vendor resources/vendor node_modules persist logs results
	rm -f public/storage storage/oauth-private.key storage/oauth-public.key storage/logs/* storage/debugbar/* storage/framework/views/* storage/framework/cache/* storage/framework/sessions/* npm-debug.* bootstrap/cache/*
	rm -f public/css/* public/js/* public/mix-manifest.json

install: build
	php artisan key:generate
	php artisan setup:test
	php artisan passport:install

.PHONY: dist clean fullclean build prepare

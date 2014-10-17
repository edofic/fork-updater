all: dist/fork-updater

.cabal-sandbox:
	cabal sandbox init 
	cabal install --only-dependencies -j

dist/build/fork-updater/fork-updater: .cabal-sandbox
	cabal configure
	cabal build

dist/fork-updater: dist/build/fork-updater/fork-updater
	upx -o dist/fork-updater dist/build/fork-updater/fork-updater


clean:
	rm -rf dist

clean-all: clean
	rm -rf .cabal-sandbox cabal.sandbox.config 

.PHONY: clean clean-all all

# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

# ebuild generated by hackport 0.6.6.9999

CABAL_FEATURES="lib profile haddock hoogle hscolour test-suite"
inherit haskell-cabal

DESCRIPTION="Streaming data processing library"
HOMEPAGE="https://github.com/snoyberg/conduit"
SRC_URI="https://hackage.haskell.org/package/${P}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0/${PV}"
KEYWORDS="~amd64 ~x86 ~ppc64 ~ppc64-linux"
IUSE=""

RDEPEND="dev-haskell/exceptions:=[profile?]
	>=dev-haskell/mono-traversable-1.0.7:=[profile?]
	dev-haskell/mtl:=[profile?]
	dev-haskell/primitive:=[profile?]
	>=dev-haskell/resourcet-1.2:=[profile?] <dev-haskell/resourcet-1.3:=[profile?]
	dev-haskell/text:=[profile?]
	dev-haskell/unliftio-core:=[profile?]
	dev-haskell/vector:=[profile?]
	>=dev-lang/ghc-8.0.1:=
"
DEPEND="${RDEPEND}
	>=dev-haskell/cabal-1.24.0.0
	test? ( >=dev-haskell/exceptions-0.6
		>=dev-haskell/hspec-1.3
		>=dev-haskell/quickcheck-2.7
		dev-haskell/safe
		dev-haskell/silently
		>=dev-haskell/split-0.2.0.0
		>=dev-haskell/unliftio-0.2.4.0 )
"

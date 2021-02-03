# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

# ebuild generated by hackport 0.6.4.9999

CABAL_FEATURES="lib profile haddock hoogle hscolour" # test-suite": circular depend
inherit haskell-cabal

DESCRIPTION="URI manipulation"
HOMEPAGE="https://github.com/haskell/network-uri"
SRC_URI="https://hackage.haskell.org/package/${P}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0/${PV}"
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux ~ppc64 ~ppc64-linux"
IUSE=""

RESTRICT=test # circular depend: network-uri[test]->criterion->js-flot->http->network-uri

RDEPEND=">=dev-haskell/parsec-3.1.12.0:=[profile?] <dev-haskell/parsec-3.2:=[profile?]
	>=dev-lang/ghc-7.4.1:=
"
DEPEND="${RDEPEND}
	>=dev-haskell/cabal-1.10
"

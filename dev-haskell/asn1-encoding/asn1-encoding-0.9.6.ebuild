# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

# ebuild generated by hackport 0.6.1.9999

CABAL_FEATURES="lib profile haddock hoogle hscolour test-suite"
inherit haskell-cabal

DESCRIPTION="ASN1 data reader and writer in RAW, BER and DER forms"
HOMEPAGE="https://github.com/vincenthz/hs-asn1"
SRC_URI="https://hackage.haskell.org/package/${P}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0/${PV}"
KEYWORDS="~amd64 ~x86 ~ppc64 ~ppc64-linux"
IUSE=""

RDEPEND=">=dev-haskell/asn1-types-0.3.0:=[profile?] <dev-haskell/asn1-types-0.4:=[profile?]
	>=dev-haskell/hourglass-0.2.6:=[profile?]
	>=dev-lang/ghc-7.8.2:=
"
DEPEND="${RDEPEND}
	>=dev-haskell/cabal-1.18.1.3
	test? ( dev-haskell/mtl
		dev-haskell/tasty
		dev-haskell/tasty-quickcheck )
"

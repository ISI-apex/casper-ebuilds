# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

DESCRIPTION="Virtual for BLAS C implementation"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ppc ppc64 ~s390 ~sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE="eselect-ldso"

RDEPEND="
	!eselect-ldso? ( || (
		>=sci-libs/lapack-3.8[-eselect-ldso,blas]
		sci-libs/openblas[-eselect-ldso]
		sci-libs/blis:=[-eselect-ldso,blas,-index-64bit]
	) )
	eselect-ldso? ( || (
		>=sci-libs/lapack-3.8.0[eselect-ldso]
		sci-libs/openblas[eselect-ldso]
		sci-libs/blis[eselect-ldso,blas,-index-64bit]
	) )
"
DEPEND="${RDEPEND}"

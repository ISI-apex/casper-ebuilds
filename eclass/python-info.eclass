# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: python-info.eclass
# @MAINTAINER:
# Alexei Colin <ac@alexeicolin.com>
# @SUPPORTED_EAPIS: 4 5 6 7
# @BLURB: Get include paths from Python packages without importing them.
# @DESCRIPTION
# Some Python packages that build extensions against other python
# packages need some meta information about their dependencies,
# such as include paths for the compiler. This meta information is
# usually obtained by importing the dependency Python module and
# calling some information function in that module, like:
#
#     import numpy
#     numpy.get_include()
#
# Unfortunately, when cross-compiling, these dependencies have also been
# cross-compiled and cannot be loaded on the build host. This eclass
# provides a means to get the necessary meta information statically.

inherit python-utils-r1

# @FUNCTION python-info_get_include
# @USAGE: module
# @DESCRIPTION: Return what module.get_include() would have returned
python-info_get_include() {
	local mod=$1
	[[ -n "${mod}" ]] || die "No Python module specified"
	case "${mod}" in
		numpy)
			[[ -n "${PYTHON}" ]] || python_setup
			echo "$(python_get_sitedir)/numpy/core/include"
			;;
		petsc4py)
			[[ -n "${PETSC_DIR}" ]] || die "PETSC_DIR must be set"
			echo "${PETSC_DIR}/lib/petsc4py/include"
			;;
		*) die "Unsupported Python module: ${mod}" ;;
	esac
}

# @FUNCTION python-info_export_include
# @USAGE: module...
# @DESCRIPTION: Export MODULE_INCLUDE set to return of module.get_include()
python-info_export_include() {
	local mod
	for mod in "$@"; do
		local var="${mod^^}_INCLUDE"
		[[ -n "${mod}" ]] || die "No Python module specified"
		declare -x -g ${var}="$(python-info_get_include ${mod})"
	done
}

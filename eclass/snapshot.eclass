# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: snapshot.eclass
# @MAINTAINER:
# Alexei Colin <ac@alexeicolin.com>
# @SUPPORTED_EAPIS: 4 5 6 7
# @BLURB:Fetch specific snapshot versions from VCS.
# @DESCRIPTION
# Supports fetching specific commit from VCS based on package version.
# Timestamps are interpreted in UTC, so when viewing the log, use:
# 	TZ=UTC git log --date=iso8601-local

# @ECLASS-VARIABLE: SNAPSHOT_POS
# @REQUIRED
# @DESCRIPTION:
# The index of the first version component that's part of the snapshot
# identifier. For example, for version 1.0.0_p20200101, this index is 4.

if [[ "$(ver_cut ${SNAPSHOT_POS})" =~ ^(pre|p) ]]
then
	SS_TS="$(ver_cut $((SNAPSHOT_POS+1)))"
	SS_TS_DATE="${SS_TS:0:4}-${SS_TS:4:2}-${SS_TS:6:2}"
	SS_TS_TIME="${SS_TS:8:2}:${SS_TS:10:2}:${SS_TS:12:2}"
	if [[ -n "${SS_TS_TIME}" ]]; then
		EGIT_COMMIT_DATE="${SS_TS_DATE}T${SS_TS_TIME}+0000"
	else
		EGIT_COMMIT_DATE="${SS_TS_DATE}T00:00:00+0000"
	fi
fi

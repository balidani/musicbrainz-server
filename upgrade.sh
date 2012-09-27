#!/bin/bash -u

set -o errexit
cd `dirname $0`
eval `./admin/ShowDBDefs`

################################################################################
# Assert pre-conditions

if [ "$DB_SCHEMA_SEQUENCE" != "15" ]
then
    echo `date` : Error: Schema sequence must be 15 when you run this script
    exit -1
fi

################################################################################
# Backup and disable replication triggers

if [ "$REPLICATION_TYPE" = "$RT_MASTER" ]
then
    echo `date` : Export pending db changes
    ./admin/RunExport

    echo `date` : Drop replication triggers
    ./admin/psql READWRITE < ./admin/sql/DropReplicationTriggers.sql
fi

################################################################################
# Scripts that should run on *all* nodes (master/slave/standalone)

echo `date` : Applying admin/sql/updates/20120220-merge-duplicate-credits.sql
OUTPUT=`./admin/psql READWRITE < ./admin/sql/updates/20120220-merge-duplicate-credits.sql 2>&1` || ( echo "$OUTPUT" ; exit 1 )

echo `date` : Applying admin/sql/updates/20120822-more-text-constraints.sql
OUTPUT=`./admin/psql READWRITE < ./admin/sql/updates/20120822-more-text-constraints.sql 2>&1` || ( echo "$OUTPUT" ; exit 1 )

echo `date` : Applying admin/sql/updates/20120917-rg-st-created.sql
OUTPUT=`./admin/psql READWRITE < ./admin/sql/updates/20120917-rg-st-created.sql 2>&1` || ( echo "$OUTPUT" ; exit 1 )

echo `date` : Applying admin/sql/updates/20120922-move-statistics-tables.sql
OUTPUT=`./admin/psql READWRITE < ./admin/sql/updates/20120922-move-statistics-tables.sql 2>&1` || ( echo "$OUTPUT" ; exit 1 )

################################################################################
# Re-enable replication

if [ "$REPLICATION_TYPE" = "$RT_MASTER" ]
then
    echo `date` : Create replication triggers
    OUTPUT=`./admin/psql READWRITE < ./admin/sql/CreateReplicationTriggers.sql 2>&1` || ( echo "$OUTPUT" ; exit 1 )
fi

################################################################################
# Add constraints that apply only to master/standalone (FKS)

if [ "$REPLICATION_TYPE" != "$RT_SLAVE" ]
then
   echo `date` : Adding master constraints

   echo `date` : Applying admin/sql/updates/20120822-more-text-constraints-master.sql
   OUTPUT=`./admin/psql READWRITE < ./admin/sql/updates/20120822-more-text-constraints-master.sql 2>&1` || ( echo "$OUTPUT" ; exit 1 )
fi

################################################################################
# Bump schema sequence

DB_SCHEMA_SEQUENCE=16
echo `date` : Going to schema sequence $DB_SCHEMA_SEQUENCE
echo "UPDATE replication_control SET current_schema_sequence = $DB_SCHEMA_SEQUENCE;" | ./admin/psql READWRITE

################################################################################
# Prompt for final manual intervention

echo `date` : Done
echo `date` : UPDATE THE DB_SCHEMA_SEQUENCE IN DBDefs.pm TO $DB_SCHEMA_SEQUENCE !

# eof

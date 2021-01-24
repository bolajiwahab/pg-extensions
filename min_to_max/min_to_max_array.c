#include "postgres.h"           // basic definitions and declarations
#include "fmgr.h"               // definitions for PG_ *macros

#include "catalog/pg_type.h"    // utility for element types
#include "common/int.h"         // basic checks for element size
#include "utils/array.h"        // array utility functions and macros
#include "utils/lsyscache.h"    // get element type
#include "utils/typcache.h"     // type cache definitions

PG_MODULE_MAGIC;

/*
 * get_array_arg_replace_nulls
 *
 * get an array-valued argument in expanded form; if it's null, construct an
 * empty array value of the proper data type.  Also cache basic element type
 * information in fn_extra.
 *
 * Caution: if the input is a read/write pointer, this returns the input
 * argument; so callers must be sure that their changes are "safe", that is
 * they cannot leave the array in a corrupt state.
 *
 * If we're being called as an aggregate function, make sure any newly-made
 * expanded array is allocated in the aggregate state context, so as to save
 * copying operations.
 */
static ExpandedArrayHeader *
get_array_arg_replace_nulls(FunctionCallInfo fcinfo, int argno)
{
    ExpandedArrayHeader *eah;
    Oid element_type;
    ArrayMetaState *my_extra;
    MemoryContext resultcxt;

    /* If first time through, create datatype cache struct */
    my_extra = (ArrayMetaState *)fcinfo->flinfo->fn_extra;
    if (my_extra == NULL)
    {
        my_extra = (ArrayMetaState *)
            MemoryContextAlloc(fcinfo->flinfo->fn_mcxt,
                               sizeof(ArrayMetaState));
        my_extra->element_type = InvalidOid;
        fcinfo->flinfo->fn_extra = my_extra;
    }

    /* Figure out which context we want the result in */
    if (!AggCheckCallContext(fcinfo, &resultcxt))
        resultcxt = CurrentMemoryContext;

    /* Now collect the array value */
    if (!PG_ARGISNULL(argno))
    {
        MemoryContext oldcxt = MemoryContextSwitchTo(resultcxt);

        eah = PG_GETARG_EXPANDED_ARRAYX(argno, my_extra);
        MemoryContextSwitchTo(oldcxt);
    }
    else
    {
        /* We have to look up the array type and element type */
        Oid arr_typeid = get_fn_expr_argtype(fcinfo->flinfo, argno);

        if (!OidIsValid(arr_typeid))
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("could not determine input data type")));
        element_type = get_element_type(arr_typeid);
        if (!OidIsValid(element_type))
            ereport(ERROR,
                    (errcode(ERRCODE_DATATYPE_MISMATCH),
                     errmsg("input data type is not an array")));

        eah = construct_empty_expanded_array(element_type,
                                             resultcxt,
                                             my_extra);
    }

    return eah;
}

/*----------------------------------------------------------------------------
 * min_to_max_array :
 *		build a one-dimensional array of elements for min_to_max aggregate
 *----------------------------------------------------------------------------
 */
PG_FUNCTION_INFO_V1(min_to_max_array);

Datum
    min_to_max_array(PG_FUNCTION_ARGS)
{
    ExpandedArrayHeader *eah;
    Datum newelement;
    bool isNull;
    Datum result;
    int *dimv,
        *lb;
    int indx;
    ArrayMetaState *my_extra;

    eah = get_array_arg_replace_nulls(fcinfo, 0);
    isNull = PG_ARGISNULL(1);

    if (isNull)
        newelement = (Datum)0;
    else
        newelement = PG_GETARG_DATUM(1);

    /* check if the argument is one-dimensional array or empty */
    if (eah->ndims == 1)
    {
        /* append newelement */
        lb = eah->lbound;
        dimv = eah->dims;

        /* index of added elem is at lb[0] + (dimv[0] - 1) + 1 */
        if (pg_add_s32_overflow(lb[0], dimv[0], &indx))
            ereport(ERROR,
                    (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                     errmsg("integer out of range")));
    }
    else if (eah->ndims == 0)
        indx = 1;
    else
        ereport(ERROR,
                (errcode(ERRCODE_DATA_EXCEPTION),
                 errmsg("argument must be empty or one-dimensional array")));

    /* Perform element insertion */
    my_extra = (ArrayMetaState *)fcinfo->flinfo->fn_extra;

    result = array_set_element(EOHPGetRWDatum(&eah->hdr),
                               1, &indx, newelement, isNull,
                               -1, my_extra->typlen, my_extra->typbyval, my_extra->typalign);

    PG_RETURN_DATUM(result);
}

"use strict";

const express = require("express");
const router  = express.Router();


/* request processor */

router.use(( req, res, next ) => {
    next();
});

// when using GET just show a useless message

router.get( "/", ( req, res ) => {
    res.json({ message: "Lambda service operational andrade"});
});



router.post( "/", async( req, res, next ) => {
    let result;
    try {
        result = {result: 'ok'}

        if ( result instanceof Error ) {
            // request Error
            onError( res, result );
        }
        else if (typeof result === "object") {
            // request success
            onSuccess( res, result );
        }
    }
    catch ( e ) {
        // unknown Error
        onError( res, e );
        next( e );
    }
});

module.exports = router;

/* internal functions */

function onError( res, error ) {
    const message = ( error && error.message ) ? error.message : "unknown";
    res.status( 500 );
    res.json({
        "error": `"${message}"-Error occurred`
    });
}

function onSuccess( res, data ) {
    res.status( 200 );
    res.json({
        "result": data
    });
}

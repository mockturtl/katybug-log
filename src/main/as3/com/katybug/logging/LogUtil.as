package com.katybug.logging {
    
    import flash.utils.getQualifiedClassName;
    
	/**
	 * Helper functions for logging.
	 */
    public class LogUtil {
        
		//--------------------------------------------------------------------------
		//
		//  Class Methods
		//
		//--------------------------------------------------------------------------
        
		/**
		 * Returns the Flex <code>ILogger</code> category for a class, i.e., its 
		 * fully qualified class name (dot-separated).
		 * 
		 * @param	prototype	The <code>prototype</code> property of an AS3 
		 * <code>Object</code> subclass.
		 * @return	The fully qualified classname.
		 * 
		 * @see mx.logging.Log.getLogger()
		 */
		public static function categoryFor(prototype:Object):String {
            return getQualifiedClassName(prototype["constructor"]).replace(/::/g, ".");
        }
        
    }
    
}
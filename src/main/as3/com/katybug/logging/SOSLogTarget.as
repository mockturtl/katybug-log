/*
  Copyright (c) 2008-2009, Sönke Rohde
  All rights reserved.

  Redistribution and use in source and binary forms, with or without 
  modification, are permitted provided that the following conditions are
  met:

  * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
  
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the 
    documentation and/or other materials provided with the distribution.
  
  * Neither the name of Adobe Systems Incorporated nor the names of its 
    contributors may be used to endorse or promote products derived from 
    this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/  
/**
 * NOTICE: 
 * 
 *   I changed this file.  
 * 
 * Love, 
 * Apache License 2.0
 */
package com.katybug.logging {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.XMLSocket;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.logging.LogEvent;
	import mx.logging.LogEventLevel;
	import mx.logging.targets.LineFormattedTarget;
    
    /**
     * Connect the Flex logging system to an SOS socket server.
     * 
	 * @example The following code creates a logger.
	 * 
     * <listing version="3.0">
     * import mx.logging.Log;
     * 
     * Log.addTarget(new SOSLogTarget());
     * Log.getLogger("MyApp").debug("Log message");
     * </listing>
     * 
     * @see http://sos.powerflasher.com/
     * @see http://soenkerohde.com/2008/08/sos-logging-target/
	 * @see https://github.com/srohde/SOSLoggingTarget
     */
    public class SOSLogTarget extends LineFormattedTarget {
    
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------
		
		/**
		 * @private
		 */
        private var _history:Array = [];
        
		/**
		 * @private
		 */
		private var _port:int;
		
		/**
		 * @private
		 */
		private var _server:String = "localhost";
        
		/**
		 * @private
		 */
		private var _xmlSocket:XMLSocket = new XMLSocket();
		
        
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
			
		/**
		 * <code>SOSLogTarget</code> constructor.
		 *
         * @param server    Server address of the SOS Socket Server
		 * @param port		Port used by SOS Socket Server
         */
        public function SOSLogTarget(server:String = "localhost", port:int = 4444) {
			_server = server;
			_port = port;
			
			super.includeCategory = true;
			super.includeDate = true;
			super.includeLevel = true;
			super.includeTime = true;
			super.fieldSeparator = " ";
			super.level = LogEventLevel.ALL;
        }
        
		//--------------------------------------------------------------------------
		//
		//  Override Methods: LineFormattedTarget
		//
		//--------------------------------------------------------------------------
		
        /**
         * @inheritDoc
         */
        override public function logEvent(event:LogEvent):void {
            if (!_xmlSocket)
                return;
            
            var log:Object = {message:event.message};
            
            // SOS will track date and time for us so let's ignore those params
            
            if (includeLevel) {
                log.level = LogEvent.getLevelString(event.level);
            }
            
            log.category = includeCategory ? ILogger(event.target).category : "";
            
            if (_xmlSocket.connected) {
                send(log);
            } else {
                if (!_xmlSocket.hasEventListener(Event.CONNECT)) {
                    _xmlSocket.addEventListener(IOErrorEvent.IO_ERROR, socket_ioErrorHandler);
                    _xmlSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, socket_securityErrorHandler);
                    _xmlSocket.addEventListener(Event.CONNECT, socket_connectHandler);
                    _xmlSocket.connect(_server, _port);
                }
                _history.push(log);
            }
        }
        
		//--------------------------------------------------------------------------
		//
		//  Event Handlers
		//
		//--------------------------------------------------------------------------
		
		/**
		 * @private
		 */
        private function socket_connectHandler(event:Event):void {
            for each(var log:Object in _history) {
                send(log);
            }
            _history = [];
        }
          
		/**
		 * @private
		 */
        private function socket_ioErrorHandler(event:IOErrorEvent):void {
            _xmlSocket = null;
            _history = [];
            Log.removeTarget(this);
            Log.getLogger("SOSLogTarget").error("XMLSocket IOError {0}", event.text);
        }
        
		/**
		 * @private
		 */
        private function socket_securityErrorHandler(event:SecurityErrorEvent):void {
            _xmlSocket = null;
            _history = [];
            Log.removeTarget(this);
            Log.getLogger("SOSLogTarget").error("XMLSocket SecurityError {0}", event.text);
        }
        
		//--------------------------------------------------------------------------
		//
		//  Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * @private
		 */
        private function send(log:Object):void {
            var msg:String = log.message;
            var lines:Array = msg.split("\n");
            var commandType:String = lines.length == 1 ? "showMessage" : "showFoldMessage";
            var key:String = log.level;
            var prefix:String = "";
            if (log.category) {
                prefix += log.category + fieldSeparator;
            }
            try {
                var xmlMessage:XML = <{commandType} key={key} />;
                if (lines.length > 1) {
                    // set title with first line
                    xmlMessage.title = prefix + lines[0];
                    // remove title from message
                    xmlMessage.message = msg.substr(msg.indexOf("\n") + 1, msg.length);
                } else {
                    xmlMessage.appendChild(prefix + msg);
                }
                _xmlSocket.send("!SOS" + xmlMessage.toXMLString() + "\n");
            } catch (error:Error) {
                Log.getLogger("SOSLogTarget").warn("XML Format Error for SOS Message");
            }
        }
        
    }
}
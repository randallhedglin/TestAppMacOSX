package com.wb.software 
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.external.ExtensionContext;
	import flash.utils.Timer;
	
	[SWF(width="640", height="480", frameRate="60")]

	public final class TestAppMacOSX extends Sprite
	{
		// swf metadata values (must match above!)
		private const SWF_WIDTH     :int = 640;
		private const SWF_HEIGHT    :int = 480;
		private const SWF_FRAMERATE :int = 60;

		// stored objects
		private var m_app       :TestApp         = null;
		private var m_messenger :MacOSXMessenger = null;
		private var m_ane       :MacOSXANE       = null;
		
		// timers
		protected var m_windowVisibleTimer :Timer = null;

		// consants
		private const MACOSX_TEST_CODE :int = 0x3AC058;

		// launch image
		[Embed(source="../../../../LaunchImg.png", mimeType="image/png")]
		private var LaunchImage :Class;

		// default constructor
		public function TestAppMacOSX()
		{
			// defer to superclass
			super();
			
			// load launch image
			var launchImg :Bitmap = new LaunchImage();

			// create messenger
			m_messenger = new MacOSXMessenger(this,
											  SWF_WIDTH,
											  SWF_HEIGHT,
											  SWF_FRAMERATE);
			
			// create main app
			m_app = new TestApp(this,
								m_messenger,
								WBEngine.OSFLAG_MACOSX,
								true, // renderWhenIdle
								launchImg,
								false); // testMode
			
			// listen for added-to-stage
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		// addNativeExtensions() -- get native extensions up & running
		private function addNativeExtensions() :Boolean
		{
			// create extensions
			m_ane = new MacOSXANE();

			// perform test
			if(m_ane.testANE(MACOSX_TEST_CODE) != MACOSX_TEST_CODE)
			{
				// throw error
				throw new Error("com.wb.software.TestAppMacOSX.addNativeExtensions(): " +
								"ANE function test failed");
				
				// fail
				return(false);
			}
			
			// add full screen button
			m_ane.addFullScreenButton();
			
			// detect visibility changes
			m_ane.detectVisibilityChanges();

			// get extension context
			var extContext :ExtensionContext = m_ane.getExtensionContext();
			
			// add status event listener
			extContext.addEventListener(StatusEvent.STATUS, onStatus);

			// ok
			return(true);
		}
		
		// getANE() -- get reference to native extensions
		public function getANE() :MacOSXANE
		{
			// return object
			return(m_ane);
		}
		
		// getApp() -- get reference to base app
		public function getApp() :TestApp
		{
			// return object
			return(m_app);
		}
		
		// onAddedToStage() -- callback for added-to-stage notification
		private function onAddedToStage(e :Event) :void
		{
			// verify app
			if(!m_app)
				return;
			
			// add native extensions
			m_app.goingNative = addNativeExtensions();		
			
			// initialize app
			m_app.init();
			
			// pass to messenger
			m_messenger.onAddedToStage(e);
			
			// create window-visible timer
			m_windowVisibleTimer = new Timer(500, 1); // half a sec, 1x
			
			// add timer event listener
			m_windowVisibleTimer.addEventListener(TimerEvent.TIMER, onWindowVisibleTimer);
			
			// start timer
			m_windowVisibleTimer.start();
		}

		// onStatus() -- native-side event listener
		private function onStatus(e :StatusEvent) :void
		{
			// verify app
			if(!m_app)
				return;
			
			// check event type
			if(e.code)
				switch(e.code)
				{
					// onWindowVisibilityChanged
					case("onWindowVisibilityChanged"):

						// pause/resume as needed
						if(e.level == "true")
						{
							// restore focus
							m_app.onFocusReturned();
							
							// resume rendering
							m_app.renderResume();
						}
						else
						{
							// lose focus
							m_app.onFocusLost();
							
							// pause rendering
							m_app.renderPause();
						}
						
						// ok
						return;
				}
			
			// throw error
			throw new Error("com.wb.software.AndroidANE.onStatus(): " +
				"Invalid status message received: " + e.code ? e.code : "");
		}

		// onWindowVisibleTimer() -- callback for window-visible notification
		private function onWindowVisibleTimer(e :TimerEvent) :void
		{
			// verify messenger
			if(!m_messenger)
				return;
			
			// pass to messenger
			m_messenger.onWindowVisible();
		}
	}
}

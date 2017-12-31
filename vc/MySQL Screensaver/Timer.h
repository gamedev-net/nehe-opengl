#ifndef _TIMER_H_
#define _TIMER_H_

//Created by Kristo Kaas in 2002
//
//This file is free for any kinds of use - just don't blame me if something goes wrong :)
//You can modify it, rewrite it, copy-paste it and what-not, but I'd really appreciate
//if you included my name and a reference to nehe.gamedev.net (the place where I got the
//idea, reason and motivation to write this). I'm not very good with the licensing thingy
//so, moving on:

//Use:
// TTimer* Timer = new TTimer();
// Timer->Push(); 		//create a snapshot of the current time instance
// Timer->Pop(); 			//get the time offset since last call to Timer->Push()
// Timer->Counter();		//returns nr of milliseconds since Win was restarted
// Timer->Random(x); 	//generates a random number where 0 < return_value < x;

//Additional Notes:
//
//	If you initialize a timer class, it is confined within the scope of the file you initialize
// it in. E g - if you create a Timer in Main.cpp, and provide some "extern TTimer* Timer"
// in Global.h which is included also in Secondary.cpp, then calling Timer->Pop() in
// Secondary.cpp will return 0.
//
// Solution: add a global function "long GetTime()" (or something) to Main.cpp and its prototype
// to Global.h. From Secondary.cpp call GetTime() instead.
//
// If you don't want TTimer to reseed the internal random number generator, call its constructor
// with one parameter, it being set to false


//include to initialize a new random number
//generator based on system time
#ifdef __BORLANDC__
#include <time>
#include <windows>
#else
#include <time.h>
#include <windows.h>
#endif

class TTimer
{
	struct {
		__int64 frequency;
		double resolution;
		unsigned long mm_timer_start;
		unsigned long mm_timer_elapsed;
		bool performance_timer;
		__int64 performance_timer_start;
		__int64 performance_timer_elapsed;
	   double timer_mark;
		} timer;

	private:
		void Init(bool _randomize)
			{
			memset(&timer, 0, sizeof(timer));
			if(!QueryPerformanceFrequency((LARGE_INTEGER *) &timer.frequency))
				{
				timer.performance_timer	= FALSE;
				timer.mm_timer_start	= timeGetTime();
				timer.resolution = 1.0f / 1000;
				timer.frequency = 1000;
				timer.mm_timer_elapsed	= timer.mm_timer_start;
				}
			else
				{
				QueryPerformanceCounter((LARGE_INTEGER *) &timer.performance_timer_start);
				timer.performance_timer	= TRUE;
				timer.resolution = (double) (((double)1.0f)/((double)timer.frequency));
				timer.performance_timer_elapsed	= timer.performance_timer_start;
				}
	   	//if the flag was set, reinit the srand() function with the t_time object
		   if(_randomize)
   			{
      		time_t t;
		      srand((unsigned) time(&t));
   		   }
			}

	public:
   	TTimer() { Init(true); timer.timer_mark = Counter(); }
   	TTimer(bool _randomize) { Init(_randomize); timer.timer_mark = Counter(); }
      virtual ~TTimer() { }

      int Random(int scale = 100) { return random(scale); }

		double Counter()
			{
			__int64 time;

			if(timer.performance_timer)
				{
				QueryPerformanceCounter((LARGE_INTEGER *)&time);
				return((double)(time - timer.performance_timer_start) * timer.resolution) * 1000.0f;
				}
			else return((double)(timeGetTime() - timer.mm_timer_start) * timer.resolution) * 1000.0f;
			}

      void Push() { timer.timer_mark = Counter(); }
      unsigned long Pop() { return(Counter() - timer.timer_mark); }
};

#endif

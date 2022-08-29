// A comment for header A.

// Annoyingly, pcpp removes #pragma once.
#pragma once

void fn();

#define CAT

#define KITTEN
#ifdef KITTEN
void happy_cat();
#else // KITTEN
void sad_cat();
#endif // KITTEN

#ifdef LIFE
void singLifeFormsSong();
#else // LIFE
void sadData();
#endif // LIFE

#ifdef DEATH
void sad();
#else // DEATH
void ok();
#endif // DEATH

#ifdef HIDDEN
void secret();
#else // HIDDEN
void what();
#endif // HIDDEN

#define MEANING LIFE // This is annoying.

#if MEANING * 2 < 84
void small();
#endif // MEANING * 2 < 84

#if MEANING * 2 == 84
void life();
#endif // MEANING * 2 == 84

#if MEANING * 2 > 84
void big();
#endif // MEANING * 2 > 84

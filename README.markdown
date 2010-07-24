# impl_me

Automatically generate function definitions for C++ classes for lazy people.

## Purpose

It's very tedious to copy and paste the function declarations in a C++ header file into the implementation file, add the class name along with the curly braces. This is a simple script to ease the pain for those who're stuck in low-level land.

## Usage

    $ cat Interface.hpp
    class Interface
    {
    public:
        virtual std::string Templates(std::vector<int> nums);
        void PointersAndRefs(int * a, const int & b);

        // Functions already implemented in headers are not 
        // repeated
        int SimpleGetter()
        {
            return 42;
        }
    };

    $ ruby impl_me.rb Interface.hpp
    // TODO: Substitue ImplClass with your actual class name
    std::string ImplClass::Templates(std::vector<(int)> nums){}
    void ImplClass::PointersAndRefs(int * a, const int & b){}

    $ # Great, it's working. Let's copy-n-paste this into our IDE
    $ ruby impl_me.rb Interface.hpp | xclip

    $ # Cygwin folks can use putclip
    $ ruby impl_me.rb Interface.hpp | putclip

    $ # You can pipe through grep/sed/awk to tweak to your own preferred style
    $ ruby impl_me.rb Interface.hpp | sed 's/{}/\n{\n}\n/' | sed 's/ImplClass/MyInterface/'

## Requirements

- Ruby
- [SWIG](http://www.swig.org/) -- Most Linux distros include this; Windows users can use Cygwin version or the downloadable executable from the site.

## Why should I use this instead of <XXX>?

[Lazy C++](http://www.lazycplusplus.com/) was written specifically to address this problem. It has been long established and probably copes with complicated syntaxes better than this script. However, the fact that I need to create a separate `lzz` file just doesn't make me feel good. There are also reports of it not compiling on Mac OS X.

[Eclipse CDT](http://www.eclipse.org/cdt/) has a function called "Implement Methods" under the "Refactor" menu which basically does all this robustly. Actually, the best solution for this problem is to switch to Eclipse. This script is just a poor man's solution for those who don't want to use Eclipse for whatever reasons.

## Limitations/Known bugs

    $ cat Stress.hpp
    class Stress
    {
    public:
        // Can't handle pointers and refs inside templates right now
        // This will give bogus
        void Doom(std::vector<Interface *> interfaces);
    }

    $ ruby impl_me.rb Stress.hpp
    // TODO: Substitue ImplClass with your actual class name
    void ImplClass::Doom(Interface)> interfaces)

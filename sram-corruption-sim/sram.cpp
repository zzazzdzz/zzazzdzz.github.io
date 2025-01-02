#include <cstdio>
#include <cstdlib>
#include <vector>

// May not be right for every architecture, but whatever
typedef unsigned char uint8;
typedef unsigned short int uint16;
typedef unsigned int uint32;

const int SRAM_SIZE   = 0x2000;
const int SRAM_OFFSET = 0xa000;

class SRAM_Corruption {
    private:
        void opInit(uint16 dummy1, uint16 dummy2){
            lastResult = 0;
        }
        void opMemoryFill(uint16 destination, uint16 byte){
            sram[destination - SRAM_OFFSET] = (uint8)byte;
        }
        void opSwapNibbles(uint16 destination, uint16 dummy){
            uint8 b = sram[destination - SRAM_OFFSET];
            b = (b & 0x0F)<<4 | (b & 0xF0)>>4;
            sram[destination - SRAM_OFFSET] = b;
        }
        uint8 diffEncodeNibble(uint8 a, uint8 invert){
            uint8 c = a % 2;
            a /= 2;
            uint8 bit = lastResult & 1;
            if (invert) bit = (lastResult>>3) & 1;
            uint8 lookup[] = {0x01,0x32,0x76,0x45,0xfe,0xcd,0x89,0xba,
                              0xfe,0xcd,0x89,0xba,0x01,0x32,0x76,0x45,
                              0x08,0xc4,0xe6,0x2a,0xf7,0x3b,0x19,0xd5,
                              0xf7,0x3b,0x19,0xd5,0x08,0xc4,0xe6,0x2a};
            uint8 res = lookup[(bit == 0 ? 0 : 8) + (invert ? 16 : 0) + a];
            if (c == 0) res >>= 4;
            lastResult = res & 0xf;
            return res & 0xf;
        }
        void opDiffEncode(uint16 destination, uint16 invert){
            uint8 a = sram[destination - SRAM_OFFSET];
            uint8 left = diffEncodeNibble((a>>4) & 0xf, invert);
            uint8 right = diffEncodeNibble(a & 0xf, invert);
            sram[destination - SRAM_OFFSET] = (left << 4) | right;
        }
        void opNibbleReverse(uint16 destination, uint16 dummy){
            uint8 a = sram[destination - SRAM_OFFSET];
            uint8 lookup[] = {0x0, 0x8, 0x4, 0xc, 0x2, 0xa, 0x6 ,0xe,
                              0x1, 0x9, 0x5, 0xd, 0x3, 0xb, 0x7 ,0xf};
            uint8 left = lookup[(a>>4) & 0xf];
            uint8 right = lookup[a & 0xf];
            sram[destination - SRAM_OFFSET] = (left << 4) | right;
        }
        void opXorAddr(uint16 destination, uint16 source){
            sram[destination - SRAM_OFFSET] ^= sram[source - SRAM_OFFSET];
        }
        void opCopyAddr(uint16 destination, uint16 source){
            sram[destination - SRAM_OFFSET] = sram[source - SRAM_OFFSET];
        }
        void opBitset(uint16 destination, uint16 bit){
            sram[destination - SRAM_OFFSET] |= bit;
        }
        void opResetLastResult(uint16 dummy1, uint16 dummy2){
            lastResult = 0;
        }
        struct record_t {
            int action, param1, param2;
            record_t(int a, int b, int c){
                this->action = a;
                this->param1 = b;
                this->param2 = c;
            }
        };
        std::vector<record_t> behavior;
        FILE *fp;
        int action, parameter1, parameter2;
        uint8 lastResult;
    public:
        uint8 sram[SRAM_SIZE];
        bool loadSpriteBehavior(const char *fname){
            fp = fopen(fname, "r");
            if (!fp) return false;
            while (fscanf(fp, "%i %i %i", &action, &parameter1, &parameter2) != -1){
                behavior.push_back(record_t(action, parameter1, parameter2));
            }
            fclose(fp);
            return true;
        }
        bool loadInitialState(const char *fname){
            fp = fopen(fname, "rb");
            if (!fp) return false;
            fread(sram, 1, SRAM_SIZE, fp);
            fclose(fp);
            return true;
        }
        bool loadInitialState(uint8 *source, int length){
            for (int i=0; i<length; i++) sram[i] = source[i];
            return true;
        }
        bool clearSpriteBehavior(){
            behavior.clear();
            return true;
        }
        uint32 sramHash(){
            uint32 hash = 5381;
            uint8 *data = sram + 0x7d0;
            for (int i=0; i<10; i++){
                hash = ((hash << 5) + hash) + (uint32)(*data++);
            }
            return hash;
        }
        bool corrupt(){
            for (size_t i=0; i<behavior.size(); i++){
                // This should get neatly optimized by the compiler
                // Even though it certainly doesn't look beautiful
                if (behavior[i].action == 0)
                    opInit(behavior[i].param1, behavior[i].param2);
                else if (behavior[i].action == 1)
                    opMemoryFill(behavior[i].param1, behavior[i].param2);
                else if (behavior[i].action == 2)
                    opSwapNibbles(behavior[i].param1, behavior[i].param2);
                else if (behavior[i].action == 3)
                    opDiffEncode(behavior[i].param1, behavior[i].param2);
                else if (behavior[i].action == 4)
                    opNibbleReverse(behavior[i].param1, behavior[i].param2);
                else if (behavior[i].action == 5)
                    opXorAddr(behavior[i].param1, behavior[i].param2);
                else if (behavior[i].action == 6)
                    opCopyAddr(behavior[i].param1, behavior[i].param2);
                else if (behavior[i].action == 7)
                    opBitset(behavior[i].param1, behavior[i].param2);
                else if (behavior[i].action == 8)
                    opResetLastResult(behavior[i].param1, behavior[i].param2);
                else return false;
            }
            return true;
        }
};

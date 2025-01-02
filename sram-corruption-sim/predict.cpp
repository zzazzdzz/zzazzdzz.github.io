#include "sram.cpp"
#include <set>
#include <algorithm>
std::multiset<std::pair<int, int> > addrs;
struct match_t {
    uint8 *hex;
    int iterationsA, iterationsB, position;
};
std::set<int> addrs_uniq;
std::vector<match_t> matches;

void hexprint(uint8 *w){
    for (int i=0; i<16; i++){
        printf("%.2x ", *(w+i));
    }
    putchar('\n');
}

int main(int argc, char **argv){
    fprintf(stderr, "Reading seeded SRAM data...\n");
    SRAM_Corruption hexC6;
    hexC6.loadInitialState("sram_start.dmp");
    fprintf(stderr, "Reading sprite behavior data...\n");
    hexC6.loadSpriteBehavior("behavior_c6.txt");
    SRAM_Corruption hexDC;
    hexDC.loadSpriteBehavior("behavior_dc.txt");
    for (int i=0; i<=9999; i++){
        fprintf(stderr, "Iteration %i\n", i);
        float percent = addrs_uniq.size();
        percent /= 65536;
        percent *= 100;
        fprintf(stderr, "Reachable addresses: %.2f%% (%i/65536)\n", percent, addrs_uniq.size());
        hexDC.loadInitialState(hexC6.sram, SRAM_SIZE);
        uint32 hash = hexDC.sramHash();
        for (int j=1; j<=400; j++){
            hexDC.corrupt();
            for (int k=0; k<14; k++){
                if (hexDC.sram[0x7d0+k] == 0xd2 || hexDC.sram[0x7d0+k] == 0xc3){
                    uint16 jumpaddr = hexDC.sram[0x7d0+k+2]*256 + hexDC.sram[0x7d0+k+1];
                    uint8 *jumphex = new uint8[16];
                    for (int l=0; l<16; l++) jumphex[l] = hexDC.sram[0x7d0+l];
                    match_t st;
                    st.hex = jumphex;
                    st.iterationsA = i;
                    st.iterationsB = j;
                    st.position = k;
                    matches.push_back(st);
                    addrs.insert(std::make_pair(jumpaddr, matches.size()-1));
                    addrs_uniq.insert(jumpaddr);
                    break;
                }
            }
            if (hexDC.sramHash() == hash) break;
        }
        hexC6.corrupt();
    }
    uint16 prevaddr = -1;
    for (std::multiset<std::pair<int, int> >::iterator i = addrs.begin(); i != addrs.end(); ++i){
        uint16 addr = (*i).first;
        if (prevaddr != addr){
            printf("[[ $%.4X ]]\n", addr);
            prevaddr = addr;
        }
        match_t found = matches[(*i).second];
        printf("  Hi=%-4i Lo=%-3i    ", found.iterationsA, found.iterationsB);
        hexprint(found.hex);
    }
}

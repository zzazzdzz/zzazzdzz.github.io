#include "sram.cpp"

void hexprint(uint8 *w){
    for (int i=0; i<16; i++){
        printf("%.2x ", *(w+i));
    }
    putchar('\n');
}

int main(int argc, char **argv){
    fprintf(stderr, "Reading seeded SRAM data...\n");
    SRAM_Corruption corruption;
    corruption.loadInitialState("sram_start.dmp");
    fprintf(stderr, "Reading sprite behavior data...\n");
    corruption.loadSpriteBehavior("behavior_c6.txt");
    for (int i=1; i<=10000; i++){
        corruption.corrupt();
        printf("Iteration %i:\n    ", i);
        hexprint(corruption.sram + 0x598);
    }
}

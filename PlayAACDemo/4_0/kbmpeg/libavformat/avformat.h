//
//  avformat.h
//  PlayAACDemo
//
//  Created by chengshenggen on 7/18/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#ifndef avformat_h
#define avformat_h

#include <stdio.h>
#include "avcodec.h"

typedef struct AVPacketList{
    
    KBPacket pkt;
    struct AVPacketList *next;
    
}AVPacketList;

#endif /* avformat_h */

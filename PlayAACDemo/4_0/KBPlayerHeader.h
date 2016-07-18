//
//  KBPlayerHeader.h
//  PlayAACDemo
//
//  Created by chengshenggen on 7/18/16.
//  Copyright © 2016 Gan Tian. All rights reserved.
//

#ifndef KBPlayerHeader_h
#define KBPlayerHeader_h

#import "avformat.h"
#import "avcodec.h"

typedef struct PacketQueue{
    
    AVPacketList *first_pkt,last_pkt;
    int nb_packets;
    int size;
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    
}PacketQueue;

static void packet_queue_init(PacketQueue *q){
    memset(q, 0, sizeof(PacketQueue));
    pthread_mutex_init(&q->mutex, NULL);
    pthread_cond_init(&q->cond, NULL);
}



#endif /* KBPlayerHeader_h */

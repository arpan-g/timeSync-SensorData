/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author: Miklos Maroti, Brano Kusy (kusy@isis.vanderbilt.edu)
 * Ported to T2: 3/17/08 by Brano Kusy (branislav.kusy@gmail.com)
 */

#include "TestFtsp.h"
#include "RadioCountToLeds.h"

module TestFtspC
{
    uses
    {
        interface GlobalTime<TMilli>;
        interface Timer<TMilli> as Check;
        interface Timer<TMilli> as Alarm;
        interface TimeSyncInfo;
        interface Receive;
        interface AMSend;
        interface Packet;
        interface PacketLink;
        interface Leds;
        interface PacketTimeStamp<TMilli,uint32_t>;
        interface Boot;
        interface Read<uint16_t> as PhotoRead;
        interface Read<uint16_t> as TempRead;
        interface Read<uint16_t> as MicRead;
        interface SplitControl as RadioControl;
        interface BusyWait<TMilli,uint16_t>;
    }
}

implementation
{
    
    
    message_t msg;
    uint16_t lightSensor;
    uint16_t tempSensor;
    uint16_t micSensor;
    bool locked = FALSE;

    event void Boot.booted() {
        call RadioControl.start();
       
        call Check.startPeriodic(1000);
    }

    event message_t* Receive.receive(message_t* msgPtr, void* payload, uint8_t len)
    {
        call Leds.led0Toggle();
        if (!locked && call PacketTimeStamp.isValid(msgPtr)) {
            radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(msgPtr, sizeof(radio_count_msg_t));
            test_ftsp_msg_t* report = (test_ftsp_msg_t*)call Packet.getPayload(&msg, sizeof(test_ftsp_msg_t));

            uint32_t rxTimestamp = call PacketTimeStamp.timestamp(msgPtr);

            report->src_addr = TOS_NODE_ID;
            report->counter = rcm->counter;
            report->local_rx_timestamp = rxTimestamp;
            report->is_synced = call GlobalTime.local2Global(&rxTimestamp);
            report->global_rx_timestamp = rxTimestamp;
            report->skew_times_1000000 = (uint32_t)call TimeSyncInfo.getSkew()*1000000UL;
            report->ftsp_root_addr = call TimeSyncInfo.getRootID();
            report->ftsp_seq = call TimeSyncInfo.getSeqNum();
            report->ftsp_table_entries = call TimeSyncInfo.getNumEntries();
            report->lightSensor = lightSensor;
            report->tempSensor = tempSensor;
            report->micSensor = micSensor;
            call PacketLink.setRetries(&msg, 5);
            call PacketLink.setRetryDelay(&msg, 6);
            call Alarm.startOneShot((TOS_NODE_ID-1)*50);
            
        }

        return msgPtr;
    }

    event void AMSend.sendDone(message_t* ptr, error_t success) {
       
        locked = FALSE;
        
        return;
    }
     event void Check.fired() {
        call PhotoRead.read();
        call TempRead.read();
        call MicRead.read();
     }

    event void RadioControl.startDone(error_t err) {}
    event void RadioControl.stopDone(error_t error){}


    
  event void PhotoRead.readDone(error_t ok, uint16_t val) {
    if (ok == SUCCESS)
      {
      
        lightSensor = val;
     
      }
  }

    event void Alarm.fired(){
        if (call AMSend.send(AM_BROADCAST_ADDR, &msg, sizeof(test_ftsp_msg_t)) == SUCCESS) {
              locked = TRUE;
            }

    }

     /* Temperature sample completed. */
  event void TempRead.readDone(error_t ok, uint16_t val) {
    if (ok == SUCCESS)
      {
        tempSensor = val;
      }
  }

   event void MicRead.readDone(error_t ok, uint16_t val) {
    if (ok == SUCCESS)
      {
        micSensor = val;
      }
  }

}

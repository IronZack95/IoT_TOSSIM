#include "Timer.h"
#include "Homework4.h"
 
module Homework4C @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
    interface PacketAcknowledgements;
    interface AMPacket;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t counter = 0;
  
  void sendReq();
  void sendResp();
  
  
  //***************** Send request function ********************//
  void sendReq() {

      	request_msg* rcm = (request_msg*)call Packet.getPayload(&packet, sizeof(request_msg));
      if (rcm == NULL) {
		return;
      }

      rcm->counter = counter;
      rcm->type = REQ;
      
      if(call PacketAcknowledgements.requestAck(&packet)==SUCCESS){
      	dbg("radio_send", "Impose ack on REQ\n");	
      }
      
      if (call AMSend.send(2, &packet, sizeof(request_msg)) == SUCCESS) {		// voglio mandarlo solo al 2
		dbg("radio_send", "Sending REQ packet");	
		locked = TRUE;
		dbg_clear("radio_send", " at time %s \n", sim_time_string());
      }
      
 }        

  //****************** Task send response *****************//
  void sendResp() {

	response_msg* rcm = (response_msg*)call Packet.getPayload(&packet, sizeof(response_msg));
      if (rcm == NULL) {
		return;
      }

      rcm->counter = counter;
      rcm->type = RESP;
      rcm->data = rand();		// creo un valore random
      
      if(call PacketAcknowledgements.requestAck(&packet)==SUCCESS){
      	dbg("radio_send", "Impose ack on RESP\n");	
      }
      
      if (call AMSend.send(1, &packet, sizeof(response_msg)) == SUCCESS) {		// voglio mandarlo solo al 2
		dbg("radio_send", "Sending RESP packet");	
		locked = TRUE;
		dbg_clear("radio_send", " at time %s \n", sim_time_string());
      }
  }
  
  event void Boot.booted() {										// boot
    dbg("boot","Application booted.\n");
    call AMControl.start();
    
  }

  event void AMControl.startDone(error_t err) {						// start
    if (err == SUCCESS) {
      dbg("radio","Radio on on node %d!\n", TOS_NODE_ID);

      if(TOS_NODE_ID == 1){
      	call MilliTimer.startPeriodic(1000);
      }
    }
    else {
      dbgerror("radio", "Radio failed to start, retrying...\n");
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {						// radio control
    dbg("boot", "Radio stopped!\n");
  }
  
event void MilliTimer.fired() {										// Timer 
	counter++;
    dbg("timer", "Timer fired, counter is %hu.\n", counter);
    
    if (locked) {
      return;
    }
    else {								// send timer
    	sendReq();
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, 								// reciver
				   void* payload, uint8_t len) {
	switch(TOS_NODE_ID){
		case 1:
			if (len != sizeof(response_msg)) {return bufPtr;}
			else {
			  response_msg* rcm = (response_msg*)payload;
			  
			  dbg("radio_rec", "Received packet at time %s\n", sim_time_string());
			  dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength( bufPtr ));
			  
			  dbg_clear("radio_pack","\t\t Payload \n" );
			  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", rcm->type);
			  dbg_clear("radio_pack", "\t\t msg_counter: %hhu \n", rcm->counter);
			  dbg_clear("radio_pack", "\t\t msg_data: %hhu \n", rcm->data);
			  
			  call MilliTimer.stop();	// Fermo il timer del primo micro 	// SIMULAZIONE FINITA!
			  dbg("timer", "Timer 1 STOP, END SIMULATION!\n", counter);
			  
			  return bufPtr;
			}
			break;
		case 2:
			if (len != sizeof(request_msg)) {return bufPtr;}
			else {
			  request_msg* rcm = (request_msg*)payload;
			  
			  dbg("radio_rec", "Received packet at time %s\n", sim_time_string());
			  dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength( bufPtr ));
			  
			  dbg_clear("radio_pack","\t\t Payload \n" );
			  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", rcm->type);
			  dbg_clear("radio_pack", "\t\t msg_counter: %hhu \n", rcm->counter);
			  
			  counter = rcm->counter; 	// copio il contatore che hanno inviato e lo rimando indietro
			  sendResp();				// ritorno con la risposta
			  
			  return bufPtr;
			}
			break;
	}
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {				// Send Done
    if (&packet == bufPtr) {
      locked = FALSE;
      dbg("radio_send", "Packet sent...");
      dbg_clear("radio_send", " at time %s", sim_time_string());
      
      if(call PacketAcknowledgements.wasAcked(bufPtr) == TRUE){
        dbg_clear("radio_send", " with ACKED!\n");
        locked = FALSE;
		}
		else
		{
		    dbg_clear("radio_send", " with NOT ACKED!\n");
		}
    }
  }

}





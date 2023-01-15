/***************************************************************************
 *      Organisation    : Kernel Masters, KPHB, Hyderabad, India.          *
 *      facebook page   : www.facebook.com/kernelmasters                   *
 *      Website         : www.kernelmasters.org                            *
 *  Conducting Workshops on - Embedded Linux & Device Drivers Training.    *
 *  -------------------------------------------------------------------    *
 *  Tel : 91-9949062828, Email : kishore@kernelmasters.org                 *    
 *                                                                         *
 ***************************************************************************
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation. No warranty is attached; we cannot take *
 *   responsibility for errors or fitness for use.                         *
 ***************************************************************************/
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/module.h>
#include <linux/interrupt.h>
#include <linux/gpio.h>
#include <linux/workqueue.h>
#include <linux/jiffies.h>
#include <linux/delay.h>
#include <linux/gpio_switch.h>

static int gpio_irq = 0, id, irq_counter = 0;
int gpio_in=11;
static struct delayed_work ws;

static void wq_func(struct work_struct *work)
{
        printk("Wq_func - BH\n");
 	value = gpio_get_value(gpio_in);     
  	data_present = 1;
        wake_up(&my_queue);
}

static irqreturn_t switchIRQ_interrupt(int gpio_irq, void *id)
{
        irq_counter++;
        printk("Inside ISR - TH\n");
        printk("The count is %d\n",irq_counter);
	//schedule_work(&ws);
	mod_delayed_work(system_wq, &ws, msecs_to_jiffies(100));
        return IRQ_HANDLED;
}

static int __init gpio_init (void)
{
	int ret;
	int err;

	INIT_DELAYED_WORK(&ws, wq_func);

  	if ((err = gpio_request(gpio_in, THIS_MODULE->name)) != 0) {
  		printk("err:%d\n",err);
    		return err;
  	}
  
  	printk("err:%d\n",err);
  	if ((err = gpio_direction_input(gpio_in)) != 0) {
  		printk("err:%d\n",err);
    		gpio_free(gpio_in);
    		return err;
  	}
  	printk("err:%d\n",err);

	gpio_irq = gpio_to_irq(gpio_in);
   	printk("interrupt request number:%d\n",gpio_irq);

  	ret = request_irq(gpio_irq, switchIRQ_interrupt, IRQF_SHARED, "switchIRQ_interrupt", &id);
        printk("Ret value:%d\n",ret);
        if(ret < 0)
        {
                printk ("pin can't get interrupt\n");
                return -1;
        }
	
	irq_set_irq_type(gpio_irq, IRQF_TRIGGER_RISING);
  return 0;
}

static void __exit gpio_exit (void)
{
  	free_irq(gpio_irq, &id);
	printk("interrupt free\n");
	flush_scheduled_work ();
}
module_init(gpio_init);
module_exit(gpio_exit);

MODULE_LICENSE("GPL");

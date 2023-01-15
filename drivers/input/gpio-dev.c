/***************************************************************************
 *      Organisation    : Kernel Masters, KPHB, Hyderabad, India.          *
 *      facebook page	: www.facebook.com/kernelmasters                   *
 *                                                                         *
 *  Conducting Workshops on - Embedded Linux & Device Drivers Training.    *
 *  -------------------------------------------------------------------    *
 *  Tel : 91-9949062828, Email : kernelmasters@gmail.com                   *
 *                                                                         *
 ***************************************************************************
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation. No warranty is attached; we cannot take *
 *   responsibility for errors or fitness for use.                         *
 ***************************************************************************/

#include <linux/uaccess.h>
#include <linux/gpio.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/kernel.h> /* printk */
#include <linux/module.h>/* This Header contains the necessary stuff for the Module */
#include <linux/init.h> /* Required header for the Intialization and Cleanup Functionalities....  */
#include <linux/fs.h> /* struct file_operations, struct file and struct inode */
#include <linux/kdev_t.h>
#include <linux/wait.h>
#include <linux/sched.h>
#include <linux/semaphore.h>

#define NAME "switch_dev"

int value=0;
int data_present = 0;
wait_queue_head_t my_queue;
DECLARE_WAIT_QUEUE_HEAD(my_queue);

EXPORT_SYMBOL(value);
EXPORT_SYMBOL(data_present);
EXPORT_SYMBOL(my_queue);


static dev_t          gpio_dev;
static struct cdev    *gpio_cdev;
//static struct class * gpio_class = NULL;

ssize_t switch_read(struct file *, char __user *, size_t, loff_t *);
ssize_t switch_write(struct file *, const char __user *, size_t, loff_t *);
int switch_open(struct inode *, struct file *);
int switch_close(struct inode *, struct file *);

struct file_operations fops = {
	.owner = THIS_MODULE,
	.read = switch_read,
	.write = switch_write,
	.open = switch_open,
	.release = switch_close
};


/*Device methods */
ssize_t switch_read(struct file *filp, char __user *usr, size_t size, loff_t *off)
{
	char buff[32];
  	int len;

	printk("Reading from device\n");
	if(data_present == 0)
	{
		printk("Process %d (%s) Going to Sleep\n",current->pid,current->comm);	
		if(wait_event_interruptible(my_queue,(data_present==1)))
		{
		// error
		printk(KERN_ERR "Signal Occurs\n");
		}
		else
		{
		//success
		printk(KERN_INFO "Process awaken - Now Data is available\n");
		snprintf(buff, 32, "%d", value);
  		len = strlen(buff) + 1;

  		if (len > size)
    			return -ENOMEM;
  		if (copy_to_user(usr,buff, len) != 0)
    			return -EFAULT;
  		return len;
		}
	}
	else // data_present=1
	{
		data_present = 0;
		printk(KERN_INFO "EOF\n");
		return 0; //-EPERM;
	}
	return 0;
}

ssize_t switch_write(struct file *filp, const char __user *usr, size_t len, loff_t *off)
{
	printk("Trying to write into the device\n");
	return len; //-EPERM;
}

int switch_open(struct inode *ino, struct file *filp)
{
	printk("device opened\n");
	return 0;
}

int switch_close(struct inode *ino, struct file *filp)
{
	printk("device closed\n");
	return 0;
}

static int __init switch_init(void)
{
	int err;
        
	if ((err = alloc_chrdev_region(&gpio_dev, 0, 1, "gpioswitch")) < 0) {
                return err;
        }
	printk("Driver registered with major %d\n", MAJOR(gpio_dev));

	gpio_cdev = cdev_alloc();//allocate memory to Char Device structure
	gpio_cdev->ops = &fops;//link our file operations to the char device
	
	err=cdev_add(gpio_cdev,gpio_dev,1);//Notify the kernel abt the new device
         if(err<0)
         {
                 printk(KERN_ALERT "\nThe Char Devide has not been created......\n");
                 return (-1);
         }

/*	gpio_class = class_create(THIS_MODULE, "classgpio");
    	if (IS_ERR(gpio_class)) {
    		unregister_chrdev_region(gpio_dev, 1);
    		gpio_free(gpio_in);
    		return -EINVAL;
  	}

  	device_create(gpio_class, NULL, gpio_dev, NULL, "gpiodev");

  	cdev_init(&gpio_cdev, &fops);

  	if ((err = cdev_add(& gpio_cdev, gpio_dev, 1)) != 0) {
   		device_destroy(gpio_class, gpio_dev);
   		class_destroy(gpio_class);
   		unregister_chrdev_region(gpio_dev, 1);
   		gpio_free(gpio_in);
   		return err;
 	}*/
	return 0;
}

static void __exit switch_exit(void)
{
	cdev_del(gpio_cdev);
  	//device_destroy(gpio_class, gpio_dev);
  	//class_destroy(gpio_class); 
	unregister_chrdev_region(gpio_dev, 1);
	printk("simple switch_dev unregistered\n");
}

module_init(switch_init);
module_exit(switch_exit);

MODULE_LICENSE("GPL");
